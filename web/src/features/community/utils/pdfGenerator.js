import { jsPDF } from 'jspdf';

const loadImageBase64 = (url) => {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.crossOrigin = 'Anonymous';
    img.onload = () => {
      const canvas = document.createElement('canvas');
      canvas.width = img.width;
      canvas.height = img.height;
      const ctx = canvas.getContext('2d');
      ctx.drawImage(img, 0, 0);
      try {
        const dataURL = canvas.toDataURL('image/jpeg');
        resolve(dataURL);
      } catch {
        reject(new Error('Failed to generate image data URL (CORS issue?).'));
      }
    };
    img.onerror = () => reject(new Error('Failed to load image from URL.'));
    img.src = url;
  });
};

export async function generateHandoverPDF(winnerDetails) {
  const { campaign, category, submission, session, winner } = winnerDetails;
  
  const doc = new jsPDF();
  
  // Set up fonts and margins
  const margin = 20;
  let y = margin;
  const pageWidth = doc.internal.pageSize.getWidth();
  
  // Title
  doc.setFont('helvetica', 'bold');
  doc.setFontSize(22);
  doc.setTextColor(50, 50, 50);
  doc.text('Winning Artwork Handover', margin, y);
  y += 12;

  // Finalisation Date
  doc.setFontSize(10);
  doc.setFont('helvetica', 'normal');
  doc.setTextColor(100, 100, 100);
  const announcedDate = new Date(winner.announced_at).toLocaleString();
  doc.text(`Result Finalised: ${announcedDate}`, margin, y);
  y += 15;

  // Add the Artwork Image
  if (submission?.artwork_file_url) {
    try {
      const imgData = await loadImageBase64(submission.artwork_file_url);
      
      // Calculate aspect ratio to fit inside a box
      const maxImgWidth = 80;
      const maxImgHeight = 80;
      // We don't have the original width/height here without awaiting the image, 
      // but jsPDF will stretch it. We can just draw it fixed size for simplicity, 
      // or ideally we could get dimensions inside loadImageBase64.
      // Let's just draw it 80x80 for the handover document.
      doc.addImage(imgData, 'JPEG', margin, y, maxImgWidth, maxImgHeight);
      y += maxImgHeight + 10;
    } catch (e) {
      console.warn('Image failed to load for PDF:', e);
      doc.setFont('helvetica', 'italic');
      doc.text('[ Artwork Image Unavailable ]', margin, y);
      y += 20;
    }
  } else {
    doc.setFont('helvetica', 'italic');
    doc.text('[ No Artwork Image Provided ]', margin, y);
    y += 20;
  }

  // --- Artwork Details ---
  doc.setFontSize(14);
  doc.setFont('helvetica', 'bold');
  doc.setTextColor(30, 30, 30);
  doc.text('Artwork Information', margin, y);
  y += 8;

  doc.setFontSize(11);
  doc.setFont('helvetica', 'normal');
  doc.setTextColor(60, 60, 60);

  const addField = (label, value) => {
    doc.setFont('helvetica', 'bold');
    doc.text(`${label}: `, margin, y);
    doc.setFont('helvetica', 'normal');
    
    // Wrapping text
    const labelWidth = doc.getTextWidth(`${label}: `);
    const textLines = doc.splitTextToSize(value || 'N/A', pageWidth - margin * 2 - labelWidth);
    doc.text(textLines, margin + labelWidth, y);
    y += (textLines.length * 5) + 3;
  };

  addField('Title', submission?.artwork_title);
  addField('Artist', submission?.profiles?.display_name);
  addField('Description', submission?.artwork_description);
  addField('Cultural Inspiration', submission?.cultural_inspiration);
  
  y += 5;

  // --- Campaign Details ---
  doc.setFontSize(14);
  doc.setFont('helvetica', 'bold');
  doc.setTextColor(30, 30, 30);
  doc.text('Campaign Context', margin, y);
  y += 8;
  
  doc.setFontSize(11);
  addField('Campaign', campaign?.campaign_title);
  addField('Design Brief', campaign?.description);
  
  y += 5;

  // --- Voting Results ---
  doc.setFontSize(14);
  doc.setFont('helvetica', 'bold');
  doc.setTextColor(30, 30, 30);
  doc.text('Voting Results', margin, y);
  y += 8;

  doc.setFontSize(11);
  addField('Final Vote Count', String(winner.final_vote_count));
  addField('Session Context', session?.session_type ? session.session_type.replace('_', ' ').toUpperCase() : 'STANDARD');
  
  // Footer Note
  y = doc.internal.pageSize.getHeight() - 30;
  doc.setFillColor(245, 245, 245);
  doc.rect(margin, y, pageWidth - margin * 2, 20, 'F');
  
  doc.setFontSize(9);
  doc.setTextColor(100, 100, 100);
  doc.setFont('helvetica', 'italic');
  const footerText = 'Note: Physical artist handover and tiffin production processes occur entirely outside of this system. This document is for tracking and verification purposes only.';
  const footerLines = doc.splitTextToSize(footerText, pageWidth - margin * 2 - 10);
  doc.text(footerLines, margin + 5, y + 8);

  // Download
  doc.save(`Winner_Handover_${winner.artwork_campaign_winner_id}.pdf`);
}
